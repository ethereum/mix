/*
	This file is part of cpp-ethereum.

	cpp-ethereum is free software: you can redistribute it and/or modify
	it under the terms of the GNU General Public License as published by
	the Free Software Foundation, either version 3 of the License, or
	(at your option) any later version.

	cpp-ethereum is distributed in the hope that it will be useful,
	but WITHOUT ANY WARRANTY; without even the implied warranty of
	MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
	GNU General Public License for more details.

	You should have received a copy of the GNU General Public License
	along with cpp-ethereum.  If not, see <http://www.gnu.org/licenses/>.
*/
/** @file QFunctionDefinition.cpp
 * @author Yann yann@ethdev.com
 * @date 2014
 */

#include <libsolidity/ast/AST.h>
#include <libdevcore/SHA3.h>
#include <libdevcore/Exceptions.h>
#include "QVariableDeclaration.h"
#include "QFunctionDefinition.h"

using namespace dev::solidity;
using namespace dev::mix;

QFunctionDefinition::QFunctionDefinition(
	QObject* _parent,
	dev::solidity::FunctionTypePointer const& _f
):
	QBasicNodeDefinition(_parent, &_f->declaration()),
	m_hash(dev::sha3(_f->externalSignature())),
	m_fullHash(dev::sha3(_f->externalSignature())
)
{
	init(_f);
}

QFunctionDefinition::QFunctionDefinition(
	QObject* _parent,
	FunctionDefinition const& _f
):
	QBasicNodeDefinition(_parent, &_f),
	m_hash(dev::sha3(_f.externalSignature())),
	m_fullHash(dev::sha3(_f.externalSignature())
)
{
	for (unsigned i = 0; i < _f.parameters().size(); ++i)
		m_parameters.append(new QVariableDeclaration(parent(), _f.parameters().at(i)));

	for (unsigned i = 0; i < _f.returnParameters().size(); ++i)
		m_returnParameters.append(new QVariableDeclaration(parent(), _f.returnParameters().at(i)));
}

QFunctionDefinition::QFunctionDefinition(QObject* _parent, dev::solidity::EventDefinition const& _e):
	QBasicNodeDefinition(_parent, &_e)
{
	for (unsigned i = 0; i < _e.parameters().size(); ++i)
		m_parameters.append(new QVariableDeclaration(parent(), _e.parameters().at(i)));
	FunctionTypePointer _f = std::make_shared<FunctionType>(_e);
	m_hash = (FixedHash<4>)dev::sha3(_f->externalSignature());
	m_fullHash = dev::sha3(_f->externalSignature());
}

void QFunctionDefinition::init(dev::solidity::FunctionTypePointer _f)
{
	auto paramNames = _f->parameterNames();
	auto paramTypes = _f->parameterTypes();
	auto returnNames = _f->returnParameterNames();
	auto returnTypes = _f->returnParameterTypes();
	for (unsigned i = 0; i < paramNames.size(); ++i)
		m_parameters.append(new QVariableDeclaration(parent(), paramNames[i], paramTypes[i].get()));

	for (unsigned i = 0; i < returnNames.size(); ++i)
		m_returnParameters.append(new QVariableDeclaration(parent(), returnNames[i], returnTypes[i].get()));
}
